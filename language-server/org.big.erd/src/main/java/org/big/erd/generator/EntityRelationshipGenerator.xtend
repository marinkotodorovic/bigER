/*
 * generated by Xtext 2.24.0
 */
package org.big.erd.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.big.erd.entityRelationship.Attribute
import org.big.erd.entityRelationship.Model
import org.big.erd.entityRelationship.Entity
import org.big.erd.entityRelationship.DataType
import org.big.erd.entityRelationship.AttributeType
import org.big.erd.entityRelationship.Relationship
import java.util.Set
import org.eclipse.xtext.util.RuntimeIOException

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class EntityRelationshipGenerator extends AbstractGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		
		val diagram = resource.contents.get(0) as Model
		
		// Check whether the generate option is set
		if (diagram.generateOption === null || diagram.generateOption.generateOptionType.toString === 'off') {
			return;
		}

		val name = (diagram.name ?: 'output') + '.sql'
		try {
			/*  1 - Strong entities -> Table
			      * Attributes -> Column <name datatype>
			      * Ignore Derived
			      * Primary Key
			
			// 2 - Weak entity 
			* - always 1:N
			* 
			*/
			fsa.generateFile(name, '''
			«var Attribute primaryKey»
			«FOR entity : diagram.entities.reject[it.isWeak]»
				CREATE TABLE «entity.name» (
				«FOR attribute : entity.allAttributes.reject[it.type === AttributeType.DERIVED] SEPARATOR ', '»
					«attribute.name» «attribute.datatype.transformDataType»
				«ENDFOR»
				);«'\n'»«'\n'»
			«ENDFOR»
			'''
			)
		} catch (RuntimeIOException e) {
			throw new Error("Could not generate file. Did you open a folder?")
		}
	}

	private def transformDataType(DataType dataType) {
		// default
		if(dataType === null) {
			return 'CHAR(20)'
		}
			
		val type = dataType.type
		var size = dataType.size
		
		if (size != 0) {
			return type +  '(' + size + ')';
		}
		
		return type
	}

	private def getStrongEntity(Relationship r) {
		if (r.first.target.isWeak) {
			return r.second.target
		} else {
			return r.first.target
		}
	}

	private def getWeakEntity(Relationship r) {
		if (r.first.target.isWeak) {
			return r.first.target
		} else {
			return r.second.target
		}
	}

	private def Set<Attribute> getAllAttributes(Entity entity) {
		val attributes = newHashSet
		attributes += entity.attributes
		return attributes
	}
	
	/* 
	private def getStrongEntityName(Entity entity, Model m) {
		val weakRelationships = m.relationships.reject[!it.isWeak]
		for (Relationship r : weakRelationships) {
			if (r.left.target === entity) {
				return r.right.target.name
			}
			if (r.right.target === entity) {
				return r.left.target.name
			}
		}
	}
	*/

	private def getKey(Entity entity) {
		for(Attribute a : entity.attributes) {
			if (a.type === AttributeType.KEY) {
				return a
			}
		}
	}

	private def getLeftKey(Relationship relationship) {
		val entity = relationship.first.target
		for(Attribute a : entity.attributes) {
			if (a.type === AttributeType.KEY) {
				return a
			}
		}
	}

	private def getRightKey(Relationship relationship) {
		val entity = relationship.second.target
		for(Attribute a : entity.attributes) {
			if (a.type === AttributeType.KEY) {
				return a
			}
		}
	}

	private def getThirdKey(Relationship relationship) {
		val entity = relationship.third.target
		for(Attribute a : entity.attributes) {
			if (a.type === AttributeType.KEY) {
				return a
			}
		}
	}
}